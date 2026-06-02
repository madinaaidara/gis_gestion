// lib/presentation/viewmodels/shop_viewmodel.dart
import 'package:flutter/material.dart';
import '../../data/models/shop_model.dart';
import '../../data/repositories/shops_repository.dart';

class ShopViewModel extends ChangeNotifier {
  final ShopsRepository _shopsRepository;

  ShopViewModel(this._shopsRepository);

  bool get isLoading => _shopsRepository.isLoading;
  String get errorMessage => _shopsRepository.errorMessage;
  ShopModel? get currentShop => _shopsRepository.currentShop;

  /// Vérifie si l'utilisateur possède un commerce configuré en base
  Future<bool> checkShopExistence(String userId) async {
    return await _shopsRepository.checkAndLoadShop(userId);
  }

  /// Crée l'espace de travail d'une boutique (onboarding setup)
  Future<bool> createBoutique({
    required String ownerId,
    required String nomboutique,
    String? proprietaire,
    String? telephone,
    String? adresse,
    required String devise,
  }) async {
    final newShop = ShopModel(
      ownerId: ownerId,
      nomBoutique: nomboutique.trim(),
      proprietaire: proprietaire?.trim(),
      telephone: telephone?.trim(),
      adresse: adresse?.trim(),
      devise: devise,
      onboardingCompleted: true,
    );

    return await _shopsRepository.registerNewShop(newShop);
  }
}
