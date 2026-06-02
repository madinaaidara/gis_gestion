class AbonnementModel {
  final String? id;
  final String? shopId;
  final String? dateInstallation;
  final String? dateExpiration;
  final bool estActive;
  final String? codeActivation;
  final String? typeAbonnement;

  const AbonnementModel({
    this.id,
    this.shopId,
    this.dateInstallation,
    this.dateExpiration,
    this.estActive = false,
    this.codeActivation,
    this.typeAbonnement,
  });

  factory AbonnementModel.fromJson(Map<String, dynamic> json) {
    return AbonnementModel(
      id: json['id']?.toString(),
      shopId: json['shop_id']?.toString(),
      dateInstallation: json['date_installation']?.toString(),
      dateExpiration: json['date_expiration']?.toString(),
      estActive: json['est_active'] == true,
      codeActivation: json['code_activation']?.toString(),
      typeAbonnement: json['type_abonnement']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final data = {
      'est_active': estActive,
      'code_activation': codeActivation,
      'type_abonnement': typeAbonnement,
    };
    if (id != null) data['id'] = id;
    if (shopId != null) data['shop_id'] = shopId;
    if (dateInstallation != null) data['date_installation'] = dateInstallation;
    if (dateExpiration != null) data['date_expiration'] = dateExpiration;
    return data;
  }
}
