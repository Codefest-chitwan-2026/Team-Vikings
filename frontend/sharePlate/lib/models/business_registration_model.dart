class BusinessRegistrationModel {
  String businessName;
  String contactName;
  String phoneNumber;
  String email;
  String password;
  String addressText;
  String registrationOrPanNumber;
  double? latitude;
  double? longitude;
  String? verificationDocumentPath;

  BusinessRegistrationModel({
    this.businessName = '',
    this.contactName = '',
    this.phoneNumber = '',
    this.email = '',
    this.password = '',
    this.addressText = '',
    this.registrationOrPanNumber = '',
    this.latitude,
    this.longitude,
    this.verificationDocumentPath,
  });

  Map<String, String> toFormFields() => {
        'phone_num': phoneNumber.trim(),
        'email': email.trim(),
        'password': password,
        'business_name': businessName.trim(),
        'registration_number': registrationOrPanNumber.trim(),
        'address': addressText.trim(),
        if (latitude != null) 'latitude': latitude.toString(),
        if (longitude != null) 'longitude': longitude.toString(),
      };

  Map<String, dynamic> toJson() => {
        'business_name': businessName,
        'contact_name': contactName,
        'phone_number': phoneNumber,
        'email': email,
        'password': password,
        'address_text': addressText,
        'registration_or_pan_number': registrationOrPanNumber,
        'latitude': latitude,
        'longitude': longitude,
        'verification_document_path': verificationDocumentPath,
      };
}
