class CustomerProfileModel {
  final int? id;
  final int? userId;
  final String fullName;
  final String address;

  CustomerProfileModel({
    this.id,
    this.userId,
    required this.fullName,
    required this.address,
  });

  factory CustomerProfileModel.fromJson(Map<String, dynamic> json) {
    return CustomerProfileModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      userId: json['user'] is int ? json['user'] : int.tryParse(json['user']?.toString() ?? ''),
      fullName: json['full_name'] ?? '',
      address: json['address'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user': userId,
        'full_name': fullName,
        'address': address,
      };
}
