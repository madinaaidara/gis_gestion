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

  DateTime? get expirationDate {
    if (dateExpiration == null) return null;
    return DateTime.tryParse(dateExpiration!);
  }

  bool get isExpired {
    final exp = expirationDate;
    if (exp == null) return !estActive;
    return DateTime.now().isAfter(exp);
  }

  bool get isValid => estActive && !isExpired;

  int get daysRemaining {
    final exp = expirationDate;
    if (exp == null) return 0;
    return exp.difference(DateTime.now()).inDays.clamp(0, 9999);
  }

  String get planLabel {
    switch (typeAbonnement) {
      case 'pro':
        return 'Pro';
      case 'annuel':
        return 'Annuel';
      case 'essai':
        return 'Essai gratuit';
      default:
        return typeAbonnement ?? 'Standard';
    }
  }

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
    final data = <String, dynamic>{
      'est_active': estActive,
      'type_abonnement': typeAbonnement,
    };
    if (id != null) data['id'] = id;
    if (shopId != null) data['shop_id'] = shopId;
    if (dateInstallation != null) data['date_installation'] = dateInstallation;
    if (dateExpiration != null) data['date_expiration'] = dateExpiration;
    if (codeActivation != null) data['code_activation'] = codeActivation;
    return data;
  }
}
