class CreditModel {
  final String? id;
  final String? shopId;
  final String clientNom;
  final String? telephoneClient;
  final double montantTotal;
  final double montantPaye;
  final double reste;
  final String? statut;
  final String? note;
  final String? dateCredit;
  final String? createdAt;

  const CreditModel({
    this.id,
    this.shopId,
    required this.clientNom,
    this.telephoneClient,
    this.montantTotal = 0.0,
    this.montantPaye = 0.0,
    this.reste = 0.0,
    this.statut = 'en_cours',
    this.note,
    this.dateCredit,
    this.createdAt,
  });

  factory CreditModel.fromJson(Map<String, dynamic> json) {
    return CreditModel(
      id: json['id']?.toString(),
      shopId: json['shop_id']?.toString(),
      clientNom: json['client_nom']?.toString() ?? '',
      telephoneClient: json['telephone_client']?.toString(),
      montantTotal: _toDouble(json['montant_total']),
      montantPaye: _toDouble(json['montant_paye']),
      reste: _toDouble(json['reste']),
      statut: json['statut']?.toString() ?? 'en_cours',
      note: json['note']?.toString(),
      dateCredit: json['date_credit']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final data = {
      'client_nom': clientNom,
      'telephone_client': telephoneClient,
      'montant_total': montantTotal,
      'montant_paye': montantPaye,
      'reste': reste,
      'statut': statut,
      'note': note,
    };
    if (id != null) data['id'] = id;
    if (shopId != null) data['shop_id'] = shopId;
    if (dateCredit != null) data['date_credit'] = dateCredit;
    if (createdAt != null) data['created_at'] = createdAt;
    return data;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}
