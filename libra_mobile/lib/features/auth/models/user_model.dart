class UserModel {
  final int id;
  final String email;
  final String name;
  final String phone;
  final String address;
  final String createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.address,
    required this.createdAt,
  });

  // fromJson — converts Django API response JSON into a UserModel object
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
  // toJson — converts UserModel back to JSON (for sending to API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'address': address,
      'created_at': createdAt,
    };
  }
}
