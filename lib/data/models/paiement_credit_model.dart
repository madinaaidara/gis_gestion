class PaiementCreditModel {
  final String? id;
  final String? creditId;
  final double montant;
  final String? datePaiement;
  final String? note;

  const PaiementCreditModel({
    this.id,
    this.creditId,
    this.montant = 0.0,
    this.datePaiement,
    this.note,
  });

  factory PaiementCreditModel.fromJson(Map<String, dynamic> json) {
    return PaiementCreditModel(
      id: json['id']?.toString(),
      creditId: json['credit_id']?.toString(),
      montant: _toDouble(json['montant']),
      datePaiement: json['date_paiement']?.toString(),
      note: json['note']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final data = {
      'montant': montant,
      'note': note,
    };
    if (id != null) data['id'] = id;
    if (creditId != null) data['credit_id'] = creditId;
    if (datePaiement != null) data['date_paiement'] = datePaiement;
    return data;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}
