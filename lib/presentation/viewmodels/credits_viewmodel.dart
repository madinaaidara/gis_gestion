// lib/presentation/viewmodels/credits_viewmodel.dart
import 'package:flutter/material.dart';
import '../../data/models/credit_model.dart';
import '../../data/repositories/credits_repository.dart';

class CreditsViewModel extends ChangeNotifier {
  final CreditsRepository _creditsRepository;

  CreditsViewModel(this._creditsRepository);

  bool get isLoading => _creditsRepository.isLoading;
  List<CreditModel> get allCredits => _creditsRepository.credits;

  String _currentFilter = 'all'; // 'all', 'en_cours', 'paye'
  String _searchQuery = '';

  String get currentFilter => _currentFilter;
  String get searchQuery => _searchQuery;

  /// Charger les dettes
  Future<void> loadCredits(String shopId) async {
    await _creditsRepository.fetchCredits(shopId);
  }

  /// Applique le filtrage dynamique et la recherche par nom/téléphone
  List<CreditModel> get filteredCredits {
    final search = _searchQuery.trim().toLowerCase();

    return _creditsRepository.credits.where((credit) {
      // Filtre d'onglet
      if (_currentFilter == 'en_cours' && credit.statut != 'en_cours') return false;
      if (_currentFilter == 'paye' && credit.statut != 'paye') return false;

      // Filtre textuel
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

  /// Enregistrer un acompte de remboursement client
  Future<bool> effectuerVersement(String creditId, double montantSaisi) async {
    return await _creditsRepository.encaisserRemboursement(creditId, montantSaisi);
  }
}
