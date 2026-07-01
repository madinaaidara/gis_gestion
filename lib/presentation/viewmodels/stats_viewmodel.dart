import 'package:flutter/material.dart';
import '../../data/repositories/stats_repository.dart';

class StatsViewModel extends ChangeNotifier {
  final StatsRepository _statsRepository;

  bool _isLoading = false;
  String _errorMessage = '';
  String _selectedPeriode = 'mois';

  Map<String, dynamic> _dashboardData = {};
  Map<String, dynamic> _ventesParJour = {};
  Map<String, dynamic> _topProducts = {};
  Map<String, dynamic> _evolutionData = {};
  Map<String, dynamic> _calendarData = {};

  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDay;
  List<Map<String, dynamic>> _selectedDayVentes = [];
  bool _loadingDayDetail = false;

  StatsViewModel(this._statsRepository);

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String get selectedPeriode => _selectedPeriode;
  DateTime get focusedMonth => _focusedMonth;
  DateTime? get selectedDay => _selectedDay;
  List<Map<String, dynamic>> get selectedDayVentes => _selectedDayVentes;
  bool get loadingDayDetail => _loadingDayDetail;

  double get totalCA => (_dashboardData['total_ca'] as num?)?.toDouble() ?? 0.0;
  double get evolutionCA => (_dashboardData['evolution_ca'] as num?)?.toDouble() ?? 0.0;
  int get totalVentes => (_dashboardData['total_ventes'] as num?)?.toInt() ?? 0;
  double get evolutionVentes => (_dashboardData['evolution_ventes'] as num?)?.toDouble() ?? 0.0;
  double get beneficeTotal => (_dashboardData['benefice_total'] as num?)?.toDouble() ?? 0.0;
  double get evolutionBenefice => (_dashboardData['evolution_benefice'] as num?)?.toDouble() ?? 0.0;
  int get totalClients => (_dashboardData['total_clients'] as num?)?.toInt() ?? 0;
  double get tauxCredits => (_dashboardData['taux_credits'] as num?)?.toDouble() ?? 0.0;
  double get panierMoyen => (_dashboardData['panier_moyen'] as num?)?.toDouble() ?? 0.0;
  double get margePercent => (_dashboardData['marge_percent'] as num?)?.toDouble() ?? 0.0;
  double get caComptant => (_dashboardData['ca_comptant'] as num?)?.toDouble() ?? 0.0;
  double get caCredit => (_dashboardData['ca_credit'] as num?)?.toDouble() ?? 0.0;

  double get calendarMonthCA => (_calendarData['total_ca'] as num?)?.toDouble() ?? 0.0;
  int get calendarMonthVentes => (_calendarData['total_ventes'] as num?)?.toInt() ?? 0;
  int get calendarJoursActifs => (_calendarData['jours_actifs'] as num?)?.toInt() ?? 0;
  String get calendarMeilleurJour => _calendarData['meilleur_jour']?.toString() ?? '';
  double get calendarMeilleurJourCA => (_calendarData['meilleur_jour_ca'] as num?)?.toDouble() ?? 0.0;
  double get calendarMaxCaJour => (_calendarData['max_ca_jour'] as num?)?.toDouble() ?? 0.0;

  Map<String, Map<String, dynamic>> get calendarDays {
    final raw = _calendarData['days'];
    if (raw is! Map) return {};
    return raw.map((k, v) => MapEntry(k.toString(), Map<String, dynamic>.from(v as Map)));
  }

  List<Map<String, dynamic>> get chartData {
    final data = _ventesParJour['data'] ?? [];
    return List<Map<String, dynamic>>.from(data);
  }

  List<Map<String, dynamic>> get topProductsList {
    final products = _topProducts['products'] ?? [];
    return List<Map<String, dynamic>>.from(products);
  }

  List<Map<String, dynamic>> get evolutionChartData {
    final data = _evolutionData['data'] ?? [];
    return List<Map<String, dynamic>>.from(data);
  }

  /// Sections pour graphique circulaire top produits (top 3 + autres)
  List<Map<String, dynamic>> get topProductsDonut {
    final products = topProductsList;
    if (products.isEmpty) return [];

    final top3 = products.take(3).toList();
    final top3Ca = top3.fold(0.0, (s, p) => s + ((p['ca'] as num?)?.toDouble() ?? 0));
    final totalCa = products.fold(0.0, (s, p) => s + ((p['ca'] as num?)?.toDouble() ?? 0));
    final autres = totalCa - top3Ca;

    final result = top3
        .map((p) => {
              'label': p['nom']?.toString() ?? 'Produit',
              'value': (p['ca'] as num?)?.toDouble() ?? 0.0,
            })
        .toList();

    if (autres > 0.01) {
      result.add({'label': 'Autres', 'value': autres});
    }
    return result;
  }

  String get periodeLabel {
    switch (_selectedPeriode) {
      case 'semaine':
        return '7 derniers jours';
      case 'mois':
        return '30 derniers jours';
      case 'annee':
        return '12 derniers mois';
      default:
        return 'Période';
    }
  }

  /// Taux d'activité : jours avec ventes / jours de la période
  double get tauxActivite {
    final joursPeriode = _selectedPeriode == 'semaine'
        ? 7
        : _selectedPeriode == 'mois'
            ? 30
            : 365;
    if (joursPeriode == 0) return 0;
    return (chartData.length / joursPeriode * 100).clamp(0, 100);
  }

  Map<String, dynamic>? dayData(DateTime day) {
    return calendarDays[_dayKey(day)];
  }

  double dayCa(DateTime day) => (dayData(day)?['ca'] as num?)?.toDouble() ?? 0.0;

  String _dayKey(DateTime day) =>
      '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

  /// Messages d'analyse automatiques basés sur les vraies données
  List<Map<String, String>> get analysisCards {
    final cards = <Map<String, String>>[];

    if (totalVentes == 0) {
      cards.add({
        'title': 'Pas encore de données',
        'body':
            'Effectuez vos premières ventes depuis l\'onglet Caisse. Les statistiques, le calendrier et les graphiques se rempliront automatiquement.',
        'type': 'info',
      });
      return cards;
    }

    final evo = evolutionCA;
    if (evo.abs() >= 0.1) {
      cards.add({
        'title': evo >= 0 ? 'Croissance du chiffre d\'affaires' : 'Baisse du chiffre d\'affaires',
        'body': evo >= 0
            ? 'Votre CA a augmenté de ${evo.toStringAsFixed(1)} % par rapport à la période précédente (${periodeLabel.toLowerCase()}). Continuez sur cette lancée.'
            : 'Votre CA a baissé de ${evo.abs().toStringAsFixed(1)} % vs la période précédente. Vérifiez vos produits les moins vendus et relancez la promotion.',
        'type': evo >= 0 ? 'success' : 'warning',
      });
    }

    cards.add({
      'title': 'Comprendre votre marge',
      'body':
          'Sur ${_formatShort(totalCA)} de ventes, vous avez réalisé ${_formatShort(beneficeTotal)} de bénéfice net, soit une marge de ${margePercent.toStringAsFixed(1)} %. '
          'Cela signifie que pour chaque 100 unités vendues, environ ${margePercent.toStringAsFixed(0)} unités restent en profit après achat.',
      'type': 'info',
    });

    if (tauxCredits > 15) {
      cards.add({
        'title': 'Attention aux crédits',
        'body':
            '${tauxCredits.toStringAsFixed(0)} % de vos ventes sont à crédit (${_formatShort(caCredit)} sur ${_formatShort(totalCA)}). '
            'Un taux élevé peut impacter votre trésorerie — suivez les dossiers dans l\'onglet Crédits.',
        'type': 'warning',
      });
    } else if (caCredit > 0) {
      cards.add({
        'title': 'Crédits sous contrôle',
        'body':
            'Seulement ${tauxCredits.toStringAsFixed(0)} % des ventes sont à crédit. La majorité de votre CA (${_formatShort(caComptant)}) est encaissée comptant.',
        'type': 'success',
      });
    }

    if (topProductsList.isNotEmpty) {
      final top = topProductsList.first;
      final part = totalCA > 0 ? ((top['ca'] as num?)?.toDouble() ?? 0) / totalCA * 100 : 0;
      cards.add({
        'title': 'Produit star',
        'body':
            '« ${top['nom']} » génère ${part.toStringAsFixed(0)} % de votre CA (${_formatShort((top['ca'] as num?)?.toDouble() ?? 0)}). '
            'Assurez-vous d\'avoir toujours du stock disponible.',
        'type': 'info',
      });
    }

    if (calendarMeilleurJour.isNotEmpty && calendarMeilleurJourCA > 0) {
      final parts = calendarMeilleurJour.split('-');
      final label = parts.length == 3 ? '${parts[2]}/${parts[1]}/${parts[0]}' : calendarMeilleurJour;
      cards.add({
        'title': 'Meilleur jour du mois',
        'body':
            'Le $label a été votre journée la plus rentable avec ${_formatShort(calendarMeilleurJourCA)} de CA. '
            'Analysez ce qui a fonctionné ce jour-là (promotions, affluence, produits).',
        'type': 'success',
      });
    }

    if (panierMoyen > 0) {
      cards.add({
        'title': 'Panier moyen',
        'body':
            'Chaque transaction rapporte en moyenne ${_formatShort(panierMoyen)}. '
            'Pour l\'augmenter, proposez des produits complémentaires ou des lots avant l\'encaissement.',
        'type': 'info',
      });
    }

    return cards;
  }

  String _formatShort(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  Future<void> loadStatsData(String shopId) async {
    if (shopId.isEmpty) {
      _errorMessage = 'ID de boutique invalide';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await Future.wait([
        _loadDashboardData(shopId),
        _loadVentesParJour(shopId),
        _loadTopProducts(shopId),
        _loadEvolutionData(shopId),
        loadCalendarMonth(shopId, _focusedMonth),
      ]);
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Impossible de charger les statistiques';
      debugPrint('❌ Erreur chargement stats: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> changePeriode(String periode, String shopId) async {
    if (shopId.isEmpty || _selectedPeriode == periode) return;
    _selectedPeriode = periode;
    notifyListeners();
    await loadStatsData(shopId);
  }

  Future<void> loadCalendarMonth(String shopId, DateTime month) async {
    _focusedMonth = DateTime(month.year, month.month);
    try {
      _calendarData = await _statsRepository.getCalendarMonthData(shopId, month.year, month.month);
    } catch (e) {
      _calendarData = {};
    }
    notifyListeners();
  }

  Future<void> selectDay(String shopId, DateTime day) async {
    _selectedDay = DateTime(day.year, day.month, day.day);
    _loadingDayDetail = true;
    notifyListeners();

    try {
      _selectedDayVentes = await _statsRepository.getVentesDuJour(shopId, _selectedDay!);
    } catch (e) {
      _selectedDayVentes = [];
    }

    _loadingDayDetail = false;
    notifyListeners();
  }

  Future<void> _loadDashboardData(String shopId) async {
    try {
      _dashboardData = await _statsRepository.getDashboardData(shopId, _selectedPeriode);
    } catch (e) {
      _dashboardData = {};
    }
  }

  Future<void> _loadVentesParJour(String shopId) async {
    try {
      _ventesParJour = await _statsRepository.getVentesParJour(shopId, _selectedPeriode);
    } catch (e) {
      _ventesParJour = {'data': []};
    }
  }

  Future<void> _loadTopProducts(String shopId) async {
    try {
      _topProducts = await _statsRepository.getTopProducts(shopId, _selectedPeriode);
    } catch (e) {
      _topProducts = {'products': []};
    }
  }

  Future<void> _loadEvolutionData(String shopId) async {
    try {
      _evolutionData = await _statsRepository.getEvolutionCA(shopId, _selectedPeriode);
    } catch (e) {
      _evolutionData = {'data': []};
    }
  }

  Future<void> refreshData(String shopId) => loadStatsData(shopId);

  void clearData() {
    _dashboardData = {};
    _ventesParJour = {};
    _topProducts = {};
    _evolutionData = {};
    _calendarData = {};
    _selectedDay = null;
    _selectedDayVentes = [];
    _errorMessage = '';
    notifyListeners();
  }
}
