class CategoryModel {
  final String? id;
  final String? shopId;
  final String nom;
  final String? description;
  final String? createdAt;

  const CategoryModel({
    this.id,
    this.shopId,
    required this.nom,
    this.description,
    this.createdAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id']?.toString(),
      shopId: json['shop_id']?.toString(),
      nom: json['nom']?.toString() ?? '',
      description: json['description']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'nom': nom,
      'description': description,
    };
    if (id != null) data['id'] = id;
    if (shopId != null) data['shop_id'] = shopId;
    if (createdAt != null) data['created_at'] = createdAt;
    return data;
  }
}
