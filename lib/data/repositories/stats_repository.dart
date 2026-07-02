import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StatsRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isAnnulee(Map<String, dynamic> vente) {
    final status = vente['status']?.toString().toLowerCase() ?? '';
    return status == 'annulee' || status == 'annulée';
  }

  /// Récupération des données du dashboard
  Future<Map<String, dynamic>> getDashboardData(String shopId, String periode) async {
    try {
      final dateRange = _getDateRange(periode);
      final datePrecedente = _getDateRangePrecedente(periode);

      final ventesActuelles = await _fetchVentes(shopId, dateRange);
      final ventesPrecedentes = await _fetchVentes(shopId, datePrecedente);

      double sumCA(List<Map<String, dynamic>> ventes) =>
          ventes.fold(0.0, (s, v) => s + ((v['total'] as num?)?.toDouble() ?? 0.0));

      double sumBenefice(List<Map<String, dynamic>> ventes) =>
          ventes.fold(0.0, (s, v) => s + ((v['benefice_reel'] as num?)?.toDouble() ?? 0.0));

      double sumComptant(List<Map<String, dynamic>> ventes) => ventes
          .where((v) => v['est_credit'] != true)
          .fold(0.0, (s, v) => s + ((v['total'] as num?)?.toDouble() ?? 0.0));

      double sumCredit(List<Map<String, dynamic>> ventes) => ventes
          .where((v) => v['est_credit'] == true)
          .fold(0.0, (s, v) => s + ((v['total'] as num?)?.toDouble() ?? 0.0));

      int countClients(List<Map<String, dynamic>> ventes) {
        final clients = <String>{};
        for (final v in ventes) {
          final nom = v['client_nom']?.toString() ?? '';
          if (nom.isNotEmpty && nom != 'Client Comptant' && nom != 'Client Créditeur') {
            clients.add(nom);
          }
        }
        return clients.length;
      }

      final caActuel = sumCA(ventesActuelles);
      final caPrecedent = sumCA(ventesPrecedentes);
      final ventesActuel = ventesActuelles.length;
      final ventesPrecedent = ventesPrecedentes.length;
      final beneficeActuel = sumBenefice(ventesActuelles);
      final beneficePrecedent = sumBenefice(ventesPrecedentes);

      return {
        'total_ca': caActuel,
        'evolution_ca': caPrecedent > 0 ? ((caActuel - caPrecedent) / caPrecedent * 100) : 0.0,
        'total_ventes': ventesActuel,
        'evolution_ventes': ventesPrecedent > 0 ? ((ventesActuel - ventesPrecedent) / ventesPrecedent * 100) : 0.0,
        'benefice_total': beneficeActuel,
        'evolution_benefice': beneficePrecedent > 0 ? ((beneficeActuel - beneficePrecedent) / beneficePrecedent * 100) : 0.0,
        'total_clients': countClients(ventesActuelles),
        'taux_credits': ventesActuel > 0
            ? (ventesActuelles.where((v) => v['est_credit'] == true).length / ventesActuel * 100)
            : 0.0,
        'panier_moyen': ventesActuel > 0 ? caActuel / ventesActuel : 0.0,
        'marge_percent': caActuel > 0 ? (beneficeActuel / caActuel * 100) : 0.0,
        'ca_comptant': sumComptant(ventesActuelles),
        'ca_credit': sumCredit(ventesActuelles),
      };
    } catch (e) {
      debugPrint('❌ Erreur getDashboardData: $e');
      return _emptyDashboard();
    }
  }

  Map<String, dynamic> _emptyDashboard() => {
        'total_ca': 0.0,
        'evolution_ca': 0.0,
        'total_ventes': 0,
        'evolution_ventes': 0.0,
        'benefice_total': 0.0,
        'evolution_benefice': 0.0,
        'total_clients': 0,
        'taux_credits': 0.0,
        'panier_moyen': 0.0,
        'marge_percent': 0.0,
        'ca_comptant': 0.0,
        'ca_credit': 0.0,
      };

  Future<List<Map<String, dynamic>>> _fetchVentes(
    String shopId,
    Map<String, String?> dateRange,
  ) async {
    final response = await _supabase
        .from('ventes')
        .select('total, benefice_reel, est_credit, client_nom, status, date_vente, nom_produit, quantite')
        .eq('shop_id', shopId)
        .gte('date_vente', dateRange['start'] ?? '')
        .lte('date_vente', dateRange['end'] ?? '');

    return List<Map<String, dynamic>>.from(response).where((v) => !_isAnnulee(v)).toList();
  }

  /// Ventes par jour pour graphique
  Future<Map<String, dynamic>> getVentesParJour(String shopId, String periode) async {
    try {
      final dateRange = _getDateRange(periode);
      final ventes = await _fetchVentes(shopId, dateRange);

      final Map<String, double> ventesParJour = {};
      for (final vente in ventes) {
        final dateVente = vente['date_vente'];
        if (dateVente == null) continue;
        final date = dateVente.toString().substring(0, 10);
        final total = (vente['total'] as num?)?.toDouble() ?? 0.0;
        ventesParJour[date] = (ventesParJour[date] ?? 0.0) + total;
      }

      final chartData = ventesParJour.entries
          .map((e) => {'date': e.key, 'total': e.value})
          .toList()
        ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));

      return {
        'data': chartData,
        'total_periode': ventesParJour.values.fold(0.0, (a, b) => a + b),
      };
    } catch (e) {
      debugPrint('❌ Erreur getVentesParJour: $e');
      return {'data': [], 'total_periode': 0.0};
    }
  }

  /// Top produits les plus vendus (parse nom_produit « Produit (x2) »)
  Future<Map<String, dynamic>> getTopProducts(String shopId, String periode) async {
    try {
      final dateRange = _getDateRange(periode);
      final ventes = await _fetchVentes(shopId, dateRange);

      final Map<String, Map<String, dynamic>> produitsAgg = {};
      final pattern = RegExp(r'^(.+?)\s*\(x\s*(\d+(?:\.\d+)?)\s*\)$', caseSensitive: false);

      for (final vente in ventes) {
        final nomRaw = vente['nom_produit']?.toString() ?? '';
        if (nomRaw.isEmpty) continue;

        final parts = nomRaw.split(', ');
        if (parts.length == 1 && !pattern.hasMatch(parts.first.trim())) {
          final qty = (vente['quantite'] as num?)?.toDouble() ?? 1.0;
          final total = (vente['total'] as num?)?.toDouble() ?? 0.0;
          _addProductAgg(produitsAgg, nomRaw.trim(), qty, total);
          continue;
        }

        for (final part in parts) {
          final match = pattern.firstMatch(part.trim());
          if (match != null) {
            final name = match.group(1)!.trim();
            final qty = double.tryParse(match.group(2)!) ?? 1.0;
            final share = parts.length > 1
                ? ((vente['total'] as num?)?.toDouble() ?? 0.0) / parts.length
                : (vente['total'] as num?)?.toDouble() ?? 0.0;
            _addProductAgg(produitsAgg, name, qty, share);
          }
        }
      }

      final topProducts = produitsAgg.entries
          .map((e) => {'nom': e.key, 'quantite': e.value['quantite'], 'ca': e.value['ca']})
          .toList()
        ..sort((a, b) => (b['ca'] as double).compareTo(a['ca'] as double));

      return {'products': topProducts.take(8).toList()};
    } catch (e) {
      debugPrint('❌ Erreur getTopProducts: $e');
      return {'products': []};
    }
  }

  void _addProductAgg(
    Map<String, Map<String, dynamic>> agg,
    String nom,
    double qty,
    double ca,
  ) {
    agg.putIfAbsent(nom, () => {'quantite': 0.0, 'ca': 0.0});
    agg[nom]!['quantite'] = (agg[nom]!['quantite'] as double) + qty;
    agg[nom]!['ca'] = (agg[nom]!['ca'] as double) + ca;
  }

  /// Évolution du CA dans le temps — série complète avec zéros sur la période.
  Future<Map<String, dynamic>> getEvolutionCA(String shopId, String periode) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final List<Map<String, dynamic>> evolutionData;

      if (periode == 'semaine') {
        evolutionData = List.generate(7, (i) {
          final day = today.subtract(Duration(days: 6 - i));
          return {
            'label': _formatEvolutionLabel(day, periode),
            'value': 0.0,
            'key': _dayKey(day),
          };
        });
      } else if (periode == 'mois') {
        evolutionData = List.generate(30, (i) {
          final day = today.subtract(Duration(days: 29 - i));
          return {
            'label': _formatEvolutionLabel(day, periode),
            'value': 0.0,
            'key': _dayKey(day),
          };
        });
      } else {
        evolutionData = List.generate(12, (i) {
          final month = DateTime(today.year, today.month - (11 - i), 1);
          return {
            'label': _formatEvolutionLabel(month, periode),
            'value': 0.0,
            'key': _monthKey(month),
          };
        });
      }

      final dateRange = _getDateRange(periode);
      final ventes = await _fetchVentes(shopId, dateRange);
      final indexByKey = {for (var i = 0; i < evolutionData.length; i++) evolutionData[i]['key'] as String: i};

      for (final vente in ventes) {
        final dateVente = vente['date_vente'];
        if (dateVente == null) continue;
        final date = DateTime.tryParse(dateVente.toString());
        if (date == null) continue;

        final key = periode == 'annee' ? _monthKey(date) : _dayKey(date);
        final idx = indexByKey[key];
        if (idx == null) continue;

        final total = (vente['total'] as num?)?.toDouble() ?? 0.0;
        evolutionData[idx]['value'] = (evolutionData[idx]['value'] as double) + total;
      }

      return {
        'data': evolutionData.map((e) => {'label': e['label'], 'value': e['value']}).toList(),
      };
    } catch (e) {
      debugPrint('❌ Erreur getEvolutionCA: $e');
      return {'data': []};
    }
  }

  String _dayKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _monthKey(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}';

  String _formatEvolutionLabel(DateTime date, String periode) {
    if (periode == 'semaine') {
      final raw = DateFormat('EEE d', 'fr_FR').format(date);
      return raw[0].toUpperCase() + raw.substring(1);
    }
    if (periode == 'mois') {
      return DateFormat('d MMM', 'fr_FR').format(date);
    }
    return DateFormat('MMM yyyy', 'fr_FR').format(date);
  }

  Map<String, String?> _getDateRange(String periode) {
    final now = DateTime.now();
    final end = now.toIso8601String();
    late DateTime startDate;

    switch (periode) {
      case 'semaine':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'mois':
        startDate = DateTime(now.year, now.month - 1, now.day);
        break;
      case 'annee':
        startDate = DateTime(now.year - 1, now.month, now.day);
        break;
      default:
        startDate = now.subtract(const Duration(days: 30));
    }

    return {'start': startDate.toIso8601String(), 'end': end};
  }

  /// Données jour par jour pour le calendrier (mois affiché)
  Future<Map<String, dynamic>> getCalendarMonthData(String shopId, int year, int month) async {
    try {
      final start = DateTime(year, month, 1);
      final end = DateTime(year, month + 1, 0, 23, 59, 59);
      final range = {'start': start.toIso8601String(), 'end': end.toIso8601String()};
      final ventes = await _fetchVentes(shopId, range);

      final Map<String, Map<String, dynamic>> days = {};
      for (final vente in ventes) {
        final dateVente = vente['date_vente'];
        if (dateVente == null) continue;
        final key = dateVente.toString().substring(0, 10);
        days.putIfAbsent(key, () => {'ca': 0.0, 'ventes': 0, 'benefice': 0.0});
        days[key]!['ca'] = (days[key]!['ca'] as double) + ((vente['total'] as num?)?.toDouble() ?? 0.0);
        days[key]!['ventes'] = (days[key]!['ventes'] as int) + 1;
        days[key]!['benefice'] =
            (days[key]!['benefice'] as double) + ((vente['benefice_reel'] as num?)?.toDouble() ?? 0.0);
      }

      var meilleurJour = '';
      var meilleurCa = 0.0;
      var totalCa = 0.0;
      var totalVentes = 0;

      for (final entry in days.entries) {
        final ca = entry.value['ca'] as double;
        totalCa += ca;
        totalVentes += entry.value['ventes'] as int;
        if (ca > meilleurCa) {
          meilleurCa = ca;
          meilleurJour = entry.key;
        }
      }

      return {
        'days': days,
        'total_ca': totalCa,
        'total_ventes': totalVentes,
        'jours_actifs': days.length,
        'meilleur_jour': meilleurJour,
        'meilleur_jour_ca': meilleurCa,
        'max_ca_jour': days.values.isEmpty
            ? 0.0
            : days.values.map((d) => d['ca'] as double).reduce((a, b) => a > b ? a : b),
      };
    } catch (e) {
      debugPrint('❌ Erreur getCalendarMonthData: $e');
      return {
        'days': <String, Map<String, dynamic>>{},
        'total_ca': 0.0,
        'total_ventes': 0,
        'jours_actifs': 0,
        'meilleur_jour': '',
        'meilleur_jour_ca': 0.0,
        'max_ca_jour': 0.0,
      };
    }
  }

  /// Détail des ventes d'un jour précis
  Future<List<Map<String, dynamic>>> getVentesDuJour(String shopId, DateTime day) async {
    try {
      final start = DateTime(day.year, day.month, day.day);
      final end = DateTime(day.year, day.month, day.day, 23, 59, 59);
      final range = {'start': start.toIso8601String(), 'end': end.toIso8601String()};
      final ventes = await _fetchVentes(shopId, range);
      ventes.sort((a, b) => (b['date_vente'] ?? '').toString().compareTo((a['date_vente'] ?? '').toString()));
      return ventes;
    } catch (e) {
      debugPrint('❌ Erreur getVentesDuJour: $e');
      return [];
    }
  }

  Map<String, String?> _getDateRangePrecedente(String periode) {
    final now = DateTime.now();
    late DateTime startDate;
    late DateTime endDate;

    switch (periode) {
      case 'semaine':
        endDate = now.subtract(const Duration(days: 7));
        startDate = endDate.subtract(const Duration(days: 7));
        break;
      case 'mois':
        endDate = DateTime(now.year, now.month - 1, now.day);
        startDate = DateTime(now.year, now.month - 2, now.day);
        break;
      case 'annee':
        endDate = DateTime(now.year - 1, now.month, now.day);
        startDate = DateTime(now.year - 2, now.month, now.day);
        break;
      default:
        endDate = now.subtract(const Duration(days: 30));
        startDate = endDate.subtract(const Duration(days: 30));
    }

    return {'start': startDate.toIso8601String(), 'end': endDate.toIso8601String()};
  }
}
