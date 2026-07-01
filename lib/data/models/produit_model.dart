/// ============================================
/// PRODUIT MODEL - GIS Gestion
/// ============================================
/// Modèle de données pour la table 'products'.
/// Sécurise la conversion JSON / Objet Dart avec gestion des types numériques.
/// ============================================

class ProduitModel {
  // CORRECTION CLÉ : Déclarée à l'intérieur des accolades de la classe
  final String? categoryNom; 
  
  final String? id;
  final String? shopId;
  final String? categoryId;
  final String nom;
  final String? description;
  final double prixAchatTotal;
  final double prixVenteUnitaire;
  final double? prixVenteGros;
  final String? uniteAchat;
  final String? uniteVente;
  final double quantiteParUnite;
  final String? uniteIntermediaire;
  final double? quantiteBaseParIntermediaire;
  final double? quantiteIntermediaireParLot;
  final double stock;
  final String? fournisseur;
  final String? telephoneFournisseur;
  final String? barcode;
  final String? imageUrl;
  final String? dateCreation;
  final String? updatedAt;
  final String? typeVente;
  final double prixAchatKg;
  final double prixVenteKg;

  const ProduitModel({
    this.categoryNom, // Placé au bon endroit dans le constructeur
    this.id,
    this.shopId,
    this.categoryId,
    required this.nom,
    this.description,
    this.prixAchatTotal = 0.0,
    this.prixVenteUnitaire = 0.0,
    this.prixVenteGros,
    this.uniteAchat,
    this.uniteVente,
    this.quantiteParUnite = 1.0,
    this.uniteIntermediaire,
    this.quantiteBaseParIntermediaire,
    this.quantiteIntermediaireParLot,
    this.stock = 0.0,
    this.fournisseur,
    this.telephoneFournisseur,
    this.barcode,
    this.imageUrl,
    this.dateCreation,
    this.updatedAt,
    this.typeVente = 'unite',
    this.prixAchatKg = 0.0,
    this.prixVenteKg = 0.0,
  });

  static const _unitesAchatGros = {'carton', 'sac', 'bidon', 'paquet', 'boîte'};

  /// Prix de revente en gros (1 lot = [uniteAchat]) renseigné
  bool get vendEnGros => (prixVenteGros ?? 0) > 0;

  /// Achat typique grossiste : lot ou fournisseur renseigné
  bool get approvisionneViaGrossiste =>
      (fournisseur != null && fournisseur!.trim().isNotEmpty) ||
      _unitesAchatGros.contains(uniteAchat);

  /// Conditionnement à 3 niveaux : paquet → sachet → pièce
  bool get hasPackagingIntermediaire =>
      uniteIntermediaire != null &&
      uniteIntermediaire!.isNotEmpty &&
      (quantiteBaseParIntermediaire ?? 0) > 0 &&
      (quantiteIntermediaireParLot ?? 0) > 0;

  /// Factory ProduitModel.fromJson
  factory ProduitModel.fromJson(Map<String, dynamic> json) {
    String? nomExtrait;
    
    // Détection de la jointure SQL brute
    if (json['categories'] != null && json['categories'] is Map) {
      nomExtrait = json['categories']['nom']?.toString();
    } 
    // Détection de la clé directe locale
    else if (json['category_nom'] != null) {
      nomExtrait = json['category_nom']?.toString();
    }

    return ProduitModel(
      categoryNom: nomExtrait,
      id: json['id']?.toString(),
      shopId: json['shop_id']?.toString(),
      categoryId: json['category_id']?.toString(),
      nom: json['nom']?.toString() ?? 'Produit sans nom',
      description: json['description']?.toString(),
      prixAchatTotal: _toDouble(json['prix_achat_total']),
      prixVenteUnitaire: _toDouble(json['prix_vente_unitaire']),
      prixVenteGros: _optionalDouble(json['prix_vente_gros']),
      uniteAchat: json['unite_achat']?.toString(),
      uniteVente: json['unite_vente']?.toString(),
      quantiteParUnite: _toDouble(json['quantite_par_unite'] ?? 1.0),
      uniteIntermediaire: json['unite_intermediaire']?.toString(),
      quantiteBaseParIntermediaire: _optionalDouble(json['quantite_base_par_intermediaire']),
      quantiteIntermediaireParLot: _optionalDouble(json['quantite_intermediaire_par_lot']),
      stock: _toDouble(json['stock']),
      fournisseur: json['fournisseur']?.toString(),
      telephoneFournisseur: json['telephone_fournisseur']?.toString(),
      barcode: json['barcode']?.toString(),
      imageUrl: json['image_url']?.toString(),
      dateCreation: json['date_creation']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      typeVente: json['type_vente']?.toString() ?? 'unite',
      prixAchatKg: _toDouble(json['prix_achat_kg']),
      prixVenteKg: _toDouble(json['prix_vente_kg']),
    );
  }

  /// ============================================
  /// SÉRIALISATION : CONVERTIR L'OBJET DART VERS MAP
  /// ============================================
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      //'category_nom': categoryNom, 
      'nom': nom,
      'description': description,
      'prix_achat_total': prixAchatTotal,
      'prix_vente_unitaire': prixVenteUnitaire,
      if (prixVenteGros != null) 'prix_vente_gros': prixVenteGros,
      'unite_achat': uniteAchat,
      'unite_vente': uniteVente,
      'quantite_par_unite': quantiteParUnite,
      'stock': stock,
      'fournisseur': fournisseur,
      'telephone_fournisseur': telephoneFournisseur,
      'barcode': barcode,
      'image_url': imageUrl,
      'type_vente': typeVente,
      'prix_achat_kg': prixAchatKg,
      'prix_vente_kg': prixVenteKg,
    };

    if (id != null) data['id'] = id;
    if (shopId != null) data['shop_id'] = shopId;
    if (categoryId != null) data['category_id'] = categoryId;
    if (dateCreation != null) data['date_creation'] = dateCreation;
    if (updatedAt != null) data['updated_at'] = updatedAt;
    if (uniteIntermediaire != null) data['unite_intermediaire'] = uniteIntermediaire;
    if (quantiteBaseParIntermediaire != null) {
      data['quantite_base_par_intermediaire'] = quantiteBaseParIntermediaire;
    }
    if (quantiteIntermediaireParLot != null) {
      data['quantite_intermediaire_par_lot'] = quantiteIntermediaireParLot;
    }

    return data;
  }

  static double? _optionalDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  /// ============================================
  /// HELPER SECURISE DE TYPECAST (ANTI-CRASH)
  /// ============================================
  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  /// ============================================
  /// COPYWITH : FACILITE LA MODIFICATION DE CHAMPS UNIQUES
  /// ============================================
  ProduitModel copyWith({
    String? categoryNom,
    String? id,
    String? shopId,
    String? categoryId,
    String? nom,
    String? description,
    double? prixAchatTotal,
    double? prixVenteUnitaire,
    double? prixVenteGros,
    String? uniteAchat,
    String? uniteVente,
    double? quantiteParUnite,
    String? uniteIntermediaire,
    double? quantiteBaseParIntermediaire,
    double? quantiteIntermediaireParLot,
    double? stock,
    String? fournisseur,
    String? telephoneFournisseur,
    String? barcode,
    String? imageUrl,
    String? dateCreation,
    String? updatedAt,
    String? typeVente,
    double? prixAchatKg,
    double? prixVenteKg,
  }) {
    return ProduitModel(
      categoryNom: categoryNom ?? this.categoryNom,
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      categoryId: categoryId ?? this.categoryId,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      prixAchatTotal: prixAchatTotal ?? this.prixAchatTotal,
      prixVenteUnitaire: prixVenteUnitaire ?? this.prixVenteUnitaire,
      prixVenteGros: prixVenteGros ?? this.prixVenteGros,
      uniteAchat: uniteAchat ?? this.uniteAchat,
      uniteVente: uniteVente ?? this.uniteVente,
      quantiteParUnite: quantiteParUnite ?? this.quantiteParUnite,
      uniteIntermediaire: uniteIntermediaire ?? this.uniteIntermediaire,
      quantiteBaseParIntermediaire:
          quantiteBaseParIntermediaire ?? this.quantiteBaseParIntermediaire,
      quantiteIntermediaireParLot:
          quantiteIntermediaireParLot ?? this.quantiteIntermediaireParLot,
      stock: stock ?? this.stock,
      fournisseur: fournisseur ?? this.fournisseur,
      telephoneFournisseur: telephoneFournisseur ?? this.telephoneFournisseur,
      barcode: barcode ?? this.barcode,
      imageUrl: imageUrl ?? this.imageUrl,
      dateCreation: dateCreation ?? this.dateCreation,
      updatedAt: updatedAt ?? this.updatedAt,
      typeVente: typeVente ?? this.typeVente,
      prixAchatKg: prixAchatKg ?? this.prixAchatKg,
      prixVenteKg: prixVenteKg ?? this.prixVenteKg,
    );
  }
}
