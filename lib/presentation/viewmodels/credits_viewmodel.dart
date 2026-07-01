import 'package:flutter/material.dart';
import '../../data/models/credit_model.dart';
import '../../data/repositories/credits_repository.dart';
import '../../data/repositories/products_repository.dart';
import '../../data/repositories/ventes_repository.dart';

class CreditsViewModel extends ChangeNotifier {
  final CreditsRepository _creditsRepository;

  CreditsViewModel(this._creditsRepository);

  bool get isLoading => _creditsRepository.isLoading;
  List<CreditModel> get allCredits => _creditsRepository.credits;

  String _currentFilter = 'all';
  String _searchQuery = '';

  String get currentFilter => _currentFilter;
  String get searchQuery => _searchQuery;

  int get totalDossiers =>
      _creditsRepository.credits.where((c) => c.statut != 'annule').length;
  int get dossiersEnCours =>
      _creditsRepository.credits.where((c) => c.statut == 'en_cours').length;
  int get dossiersPayes =>
      _creditsRepository.credits.where((c) => c.statut == 'paye').length;
  double get detteTotale => _creditsRepository.credits
      .where((c) => c.statut == 'en_cours')
      .fold(0.0, (sum, c) => sum + c.reste);

  Future<void> loadCredits(String shopId) async {
    await _creditsRepository.fetchCredits(shopId);
    notifyListeners();
  }

  List<CreditModel> get filteredCredits {
    final search = _searchQuery.trim().toLowerCase();

    return _creditsRepository.credits.where((credit) {
      if (_currentFilter == 'en_cours' && credit.statut != 'en_cours') return false;
      if (_currentFilter == 'paye' && credit.statut != 'paye') return false;

      final nom = credit.clientNom.toLowerCase();
      final tel = (credit.telephoneClient ?? '').toLowerCase();
      return nom.contains(search) || tel.contains(search);
    }).toList();
  }

  void changeFilter(String filterCode) {
    _currentFilter = filterCode;
    notifyListeners();
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<bool> effectuerVersement(String creditId, double montantSaisi) async {
    final ok = await _creditsRepository.encaisserRemboursement(creditId, montantSaisi);
    if (ok) notifyListeners();
    return ok;
  }

  Future<AnnulationCreditResult> annulerCredit(
    String creditId, {
    required ProductsRepository productsRepository,
    required VentesRepository ventesRepository,
  }) async {
    final result = await _creditsRepository.annulerCredit(
      creditId,
      productsRepository: productsRepository,
      ventesRepository: ventesRepository,
    );
    if (result.success) notifyListeners();
    return result;
  }
}
