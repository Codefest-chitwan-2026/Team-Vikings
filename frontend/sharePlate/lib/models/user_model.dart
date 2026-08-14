enum UserRole { donor, ngo, consumer }

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? phone;
  final String? organizationName;
  final String? token;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.organizationName,
    this.token,
  });

  // Convert JSON response from DRF API into UserModel
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: _parseRole(json['role']),
      phone: json['phone'],
      organizationName: json['organization_name'],
      token: json['token'] ?? json['access_token'],
    );
  }

  // Convert UserModel to JSON payload for request body
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'phone': phone,
      'organization_name': organizationName,
      'token': token,
    };
  }

  static UserRole _parseRole(String? roleStr) {
    switch (roleStr?.toLowerCase()) {
      case 'donor':
        return UserRole.donor;
      case 'ngo':
        return UserRole.ngo;
      case 'consumer':
      default:
        return UserRole.consumer;
    }
  }
}