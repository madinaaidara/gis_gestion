class ShopModel {
  final String? id;
  final String? ownerId;
  final String nomBoutique;
  final String? proprietaire;
  final String? telephone;
  final String? adresse;
  final String devise;
  final String? dateCreation;
  final String? updatedAt;
  final bool onboardingCompleted;

  const ShopModel({
    this.id,
    this.ownerId,
    required this.nomBoutique,
    this.proprietaire,
    this.telephone,
    this.adresse,
    this.devise = 'FCFA',
    this.dateCreation,
    this.updatedAt,
    this.onboardingCompleted = false,
  });

  factory ShopModel.fromJson(Map<String, dynamic> json) {
    return ShopModel(
      id: json['id']?.toString(),
      ownerId: json['owner_id']?.toString(),
      nomBoutique: json['nom_boutique']?.toString() ?? '',
      proprietaire: json['proprietaire']?.toString(),
      telephone: json['telephone']?.toString(),
      adresse: json['adresse']?.toString(),
      devise: json['devise']?.toString() ?? 'FCFA',
      dateCreation: json['date_creation']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      onboardingCompleted: json['onboarding_completed'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    final data = {
      'nom_boutique': nomBoutique,
      'proprietaire': proprietaire,
      'telephone': telephone,
      'adresse': adresse,
      'devise': devise,
      'onboarding_completed': onboardingCompleted,
    };
    if (id != null) data['id'] = id;
    if (ownerId != null) data['owner_id'] = ownerId;
    if (dateCreation != null) data['date_creation'] = dateCreation;
    if (updatedAt != null) data['updated_at'] = updatedAt;
    return data;
  }

    // À AJOUTER dans lib/data/models/shop_model.dart :
  Map<String, dynamic> toMap() {
    return toJson(); // Redirige proprement l'appel toMap vers votre logique toJson existante
  }

}
