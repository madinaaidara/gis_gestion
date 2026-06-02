class ProfileModel {
  final String? id;
  final String? email;
  final String? fullName;
  final String? phone;
  final String? createdAt;
  final String? updatedAt;

  const ProfileModel({
    this.id,
    this.email,
    this.fullName,
    this.phone,
    this.createdAt,
    this.updatedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id']?.toString(),
      email: json['email']?.toString(),
      fullName: json['full_name']?.toString(),
      phone: json['phone']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final data = {
      'email': email,
      'full_name': fullName,
      'phone': phone,
    };
    if (id != null) data['id'] = id;
    if (createdAt != null) data['created_at'] = createdAt;
    if (updatedAt != null) data['updated_at'] = updatedAt;
    return data;
  }
}
