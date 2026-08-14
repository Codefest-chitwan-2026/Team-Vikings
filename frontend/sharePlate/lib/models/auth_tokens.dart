class AuthTokens {
  final String access;
  final String refresh;

  AuthTokens({
    required this.access,
    required this.refresh,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      access: json['access'] ?? '',
      refresh: json['refresh'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'access': access,
        'refresh': refresh,
      };
}
