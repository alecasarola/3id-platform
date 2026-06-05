class FacilityProfile {
  const FacilityProfile({
    required this.id,
    required this.companyName,
    this.facilityType,
    this.vatNumber,
    this.addressStreet,
    this.addressCity,
    this.addressProvince,
    this.addressPostal,
    this.contactName,
    this.contactPhone,
    this.contactEmail,
  });

  final String id;
  final String companyName;
  final String? facilityType;    // 'hospital', 'clinic', 'rsa', 'nursing_home', 'rehabilitation', 'other'
  final String? vatNumber;

  // Sede
  final String? addressStreet;
  final String? addressCity;
  final String? addressProvince;
  final String? addressPostal;

  // Referente
  final String? contactName;
  final String? contactPhone;
  final String? contactEmail;

  String get displayAddress => [addressStreet, addressCity, addressProvince]
      .where((s) => s != null && s.isNotEmpty)
      .join(', ');

  bool get isProfileComplete =>
      companyName.isNotEmpty && addressCity != null && contactName != null;

  factory FacilityProfile.fromJson(Map<String, dynamic> json) =>
      FacilityProfile(
        id: json['id'] as String,
        companyName: json['company_name'] as String,
        facilityType: json['facility_type'] as String?,
        vatNumber: json['vat_number'] as String?,
        addressStreet: json['address_street'] as String?,
        addressCity: json['address_city'] as String?,
        addressProvince: json['address_province'] as String?,
        addressPostal: json['address_postal'] as String?,
        contactName: json['contact_name'] as String?,
        contactPhone: json['contact_phone'] as String?,
        contactEmail: json['contact_email'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'company_name': companyName,
    'facility_type': facilityType,
    'vat_number': vatNumber,
    'address_street': addressStreet,
    'address_city': addressCity,
    'address_province': addressProvince,
    'address_postal': addressPostal,
    'contact_name': contactName,
    'contact_phone': contactPhone,
    'contact_email': contactEmail,
  };

  FacilityProfile copyWith({
    String? companyName,
    String? facilityType,
    String? vatNumber,
    String? addressStreet,
    String? addressCity,
    String? addressProvince,
    String? addressPostal,
    String? contactName,
    String? contactPhone,
    String? contactEmail,
  }) =>
      FacilityProfile(
        id: id,
        companyName: companyName ?? this.companyName,
        facilityType: facilityType ?? this.facilityType,
        vatNumber: vatNumber ?? this.vatNumber,
        addressStreet: addressStreet ?? this.addressStreet,
        addressCity: addressCity ?? this.addressCity,
        addressProvince: addressProvince ?? this.addressProvince,
        addressPostal: addressPostal ?? this.addressPostal,
        contactName: contactName ?? this.contactName,
        contactPhone: contactPhone ?? this.contactPhone,
        contactEmail: contactEmail ?? this.contactEmail,
      );
}
