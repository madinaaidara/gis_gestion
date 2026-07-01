class VenteModel {
  final String? id;
  final String? shopId;
  final String? produitId;
  final String? sellerId;
  final String nomProduit;
  final double quantite;
  final double prixAchatUnitaire;
  final double prixVentePrevu;
  final double prixVenduUnitaire;
  final double total;
  final double beneficeReel;
  final String? typeVente;
  final String? clientNom;
  final String? status;
  final String? dateVente;
  final double beneficiaire;
  final String? methodePaiement;
  final bool estCredit;
  final double remise;
  final double montantPaye;
  final double resteAPayer;
  final double montantTotal;
  final String? createdAt;

  const VenteModel({
    this.id,
    this.shopId,
    this.produitId,
    this.sellerId,
    required this.nomProduit,
    this.quantite = 0.0,
    this.prixAchatUnitaire = 0.0,
    this.prixVentePrevu = 0.0,
    this.prixVenduUnitaire = 0.0,
    this.total = 0.0,
    this.beneficeReel = 0.0,
    this.typeVente,
    this.clientNom,
    this.status,
    this.dateVente,
    this.beneficiaire = 0.0,
    this.methodePaiement,
    this.estCredit = false,
    this.remise = 0.0,
    this.montantPaye = 0.0,
    this.resteAPayer = 0.0,
    this.montantTotal = 0.0,
    this.createdAt,
  });

  factory VenteModel.fromJson(Map<String, dynamic> json) {
    return VenteModel(
      id: json['id']?.toString(),
      shopId: json['shop_id']?.toString(),
      produitId: json['produit_id']?.toString(),
      sellerId: json['seller_id']?.toString(),
      nomProduit: json['nom_produit']?.toString() ?? '',
      quantite: _toDouble(json['quantite']),
      prixAchatUnitaire: _toDouble(json['prix_achat_unitaire']),
      prixVentePrevu: _toDouble(json['prix_vente_prevu']),
      prixVenduUnitaire: _toDouble(json['prix_vendu_unitaire']),
      total: _toDouble(json['total']),
      beneficeReel: _toDouble(json['benefice_reel']),
      typeVente: json['type_vente']?.toString(),
      clientNom: json['client_nom']?.toString(),
      status: json['status']?.toString(),
      dateVente: json['date_vente']?.toString(),
      beneficiaire: _toDouble(json['beneficiaire']),
      methodePaiement: json['methode_paiement']?.toString(),
      estCredit: json['est_credit'] == true,
      remise: _toDouble(json['remise']),
      montantPaye: _toDouble(json['montant_paye']),
      resteAPayer: _toDouble(json['reste_a_payer'] ?? json['reste']),
      montantTotal: _toDouble(json['montant_total']),
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final data = {
      'nom_produit': nomProduit,
      'quantite': quantite,
      'prix_achat_unitaire': prixAchatUnitaire,
      'prix_vente_prevu': prixVentePrevu,
      'prix_vendu_unitaire': prixVenduUnitaire,
      'total': total,
      'benefice_reel': beneficeReel,
      'type_vente': typeVente,
      'client_nom': clientNom,
      'status': status,
      'beneficiaire': beneficiaire,
      'methode_paiement': methodePaiement,
      'est_credit': estCredit,
      'remise': remise,
      'montant_paye': montantPaye,
      'reste_a_payer': resteAPayer,
      'montant_total': montantTotal,
    };
    if (id != null) data['id'] = id;
    if (shopId != null) data['shop_id'] = shopId;
    if (produitId != null) data['produit_id'] = produitId;
    if (sellerId != null) data['seller_id'] = sellerId;
    if (dateVente != null) data['date_vente'] = dateVente;
    if (createdAt != null) data['created_at'] = createdAt;
    return data;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}
