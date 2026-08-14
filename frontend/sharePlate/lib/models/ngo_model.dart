enum NgoOrganizationType {
  ngo('NGO'),
  orphanage('Orphanage'),
  elderlyHome('Elderly Home'),
  communityKitchen('Community Kitchen'),
  others('Others');

  final String label;
  const NgoOrganizationType(this.label);
}

class NgoRegistrationModel {
  String organizationName;
  String contactName;
  String phoneNumber;
  String email;
  String password;
  String addressText;
  double? latitude;
  double? longitude;
  String panNumber;
  NgoOrganizationType organizationType;
  String? documentPath;
  String? documentName;

  NgoRegistrationModel({
    this.organizationName = '',
    this.contactName = '',
    this.phoneNumber = '',
    this.email = '',
    this.password = '',
    this.addressText = '',
    this.latitude,
    this.longitude,
    this.panNumber = '',
    this.organizationType = NgoOrganizationType.ngo,
    this.documentPath,
    this.documentName,
  });

  Map<String, dynamic> toJson() {
    return {
      'organization_name': organizationName,
      'contact_name': contactName,
      'phone_number': phoneNumber,
      'email': email,
      'password': password,
      'address_text': addressText,
      'latitude': latitude,
      'longitude': longitude,
      'pan_number': panNumber,
      'organization_type': organizationType.label,
      'document_path': documentPath,
      'document_name': documentName,
    };
  }
}
