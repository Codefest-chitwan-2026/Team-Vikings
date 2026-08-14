enum NgoOrganizationType {
  ngo('NGO'),
  orphanage('Orphanage'),
  elderlyHome('Elderly Home'),
  communityKitchen('Community Kitchen'),
  others('Others');

  final String label;
  const NgoOrganizationType(this.label);

  String get backendValue {
    switch (this) {
      case NgoOrganizationType.elderlyHome:
        return 'Elderly Home';
      case NgoOrganizationType.orphanage:
        return 'Orphange'; // Matches Django model choice definition
      case NgoOrganizationType.ngo:
      case NgoOrganizationType.communityKitchen:
      case NgoOrganizationType.others:
        return 'NGO';
    }
  }
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

  Map<String, String> toFormFields() => {
        'phone_num': phoneNumber.trim(),
        'email': email.trim(),
        'password': password,
        'organization_name': organizationName.trim(),
        'organization_type': organizationType.backendValue,
        'registration_number': panNumber.trim(),
        'address': addressText.trim(),
        if (latitude != null) 'latitude': latitude.toString(),
        if (longitude != null) 'longitude': longitude.toString(),
      };

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
