enum UserRole { donor, ngo, consumer }

class UserModel {
  final String id;
  final String email;
  final String phone;
  final UserRole role;
  final String name;
  final String? organizationName;
  final String? address;
  final String? token;
  final String? refreshToken;
  final Map<String, dynamic>? profileData;

  UserModel({
    required this.id,
    required this.email,
    required this.phone,
    required this.role,
    this.name = '',
    this.organizationName,
    this.address,
    this.token,
    this.refreshToken,
    this.profileData,
  });

  String get displayName {
    if (name.isNotEmpty) return name;
    if (organizationName != null && organizationName!.isNotEmpty) return organizationName!;
    if (email.isNotEmpty) return email.split('@').first;
    if (phone.isNotEmpty) return phone;
    return 'User';
  }

  String get initials {
    final title = displayName.trim();
    if (title.isEmpty) return 'U';
    final parts = title.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }

  String get roleDisplayName {
    switch (role) {
      case UserRole.donor:
        return 'Donor · Food Business';
      case UserRole.ngo:
        return 'Recipient · NGO';
      case UserRole.consumer:
        return 'Consumer';
    }
  }

  bool get isDonor => role == UserRole.donor;
  bool get isNgo => role == UserRole.ngo;
  bool get isConsumer => role == UserRole.consumer;

  // Convert JSON response from DRF API into UserModel
  factory UserModel.fromJson(Map<String, dynamic> json) {
    // If the payload wraps user data inside a 'user' key
    final userMap = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : json;
    final profileMap = json['profile'] is Map<String, dynamic>
        ? json['profile'] as Map<String, dynamic>
        : null;

    final rawRole = userMap['role'] ?? json['role'];
    final parsedRole = _parseRole(rawRole?.toString());

    // Extract name or organization name from profile or user map
    String extractedName = '';
    String? extractedOrgName;
    String? extractedAddress;

    if (profileMap != null) {
      extractedName = profileMap['full_name'] ??
          profileMap['business_name'] ??
          profileMap['organization_name'] ??
          '';
      extractedOrgName = profileMap['organization_name'] ?? profileMap['business_name'];
      extractedAddress = profileMap['address'];
    } else {
      extractedName = json['name'] ?? json['full_name'] ?? '';
      extractedOrgName = json['organization_name'] ?? json['business_name'];
      extractedAddress = json['address'];
    }

    final token = json['access'] ?? json['token'] ?? json['access_token'];
    final refreshToken = json['refresh'] ?? json['refresh_token'];

    return UserModel(
      id: (userMap['id'] ?? json['id'] ?? '').toString(),
      email: (userMap['email'] ?? json['email'] ?? '').toString(),
      phone: (userMap['phone_num'] ?? userMap['phone'] ?? json['phone_num'] ?? json['phone'] ?? '').toString(),
      role: parsedRole,
      name: extractedName,
      organizationName: extractedOrgName,
      address: extractedAddress,
      token: token?.toString(),
      refreshToken: refreshToken?.toString(),
      profileData: profileMap ?? (json['profile_data'] is Map<String, dynamic> ? json['profile_data'] : null),
    );
  }

  // Convert UserModel to JSON payload for local persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone_num': phone,
      'role': _roleToBackendString(role),
      'name': name,
      'organization_name': organizationName,
      'address': address,
      'access': token,
      'refresh': refreshToken,
      'profile_data': profileData,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? phone,
    UserRole? role,
    String? name,
    String? organizationName,
    String? address,
    String? token,
    String? refreshToken,
    Map<String, dynamic>? profileData,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      name: name ?? this.name,
      organizationName: organizationName ?? this.organizationName,
      address: address ?? this.address,
      token: token ?? this.token,
      refreshToken: refreshToken ?? this.refreshToken,
      profileData: profileData ?? this.profileData,
    );
  }

  static UserRole _parseRole(String? roleStr) {
    switch (roleStr?.toUpperCase()) {
      case 'BUSINESS':
      case 'DONOR':
        return UserRole.donor;
      case 'NGO':
      case 'RECIPIENT':
        return UserRole.ngo;
      case 'CUSTOMER':
      case 'CONSUMER':
      default:
        return UserRole.consumer;
    }
  }

  static String _roleToBackendString(UserRole role) {
    switch (role) {
      case UserRole.donor:
        return 'BUSINESS';
      case UserRole.ngo:
        return 'NGO';
      case UserRole.consumer:
        return 'CUSTOMER';
    }
  }
}